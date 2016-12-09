Built-in Models
================

+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| Model Type | Description                           | States                                                                                            |
+============+=======================================+===================================================================================================+
| 21         | Linear reservoir model, with dams     | :math:`q`, :math:`S`, :math:`S_s`, :math:`S_g`                                                    |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| 40         | Linear reservoir model, with qvs dams | :math:`q`, :math:`S`, :math:`S_s`, :math:`S_g`                                                    |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| 190        | IFC model with constant runoff        | :math:`q`, :math:`s_p`, :math:`s_s`                                                               |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| 191        | IFC model with constant runoff        | :math:`q`, :math:`s_p`, :math:`s_s`, :math:`s_{precip}`, :math:`V_r`, :math:`q_b`                 |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| 252        | IFC toplayer model                    | :math:`q`, :math:`s_p`, :math:`s_t`, :math:`s_s`                                                  |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| 253        | IFC toplayer model, with reservoirs   | :math:`q`, :math:`s_p`, :math:`s_t`, :math:`s_s`                                                  |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+
| 254        | IFC toplayer model, with reservoirs   | :math:`q`, :math:`s_p`, :math:`s_t`, :math:`s_s`, :math:`s_{precip}`, :math:`V_r`, :math:`q_b`    |
+------------+---------------------------------------+---------------------------------------------------------------------------------------------------+

In this section, a description of a few different models is presented to demonstrate the features described in Section [sec: model descriptions]. These models are already fully implemented in *problems.c* and *definetype.c*, and may be used for simulations.

Constant Runoff Hydrological Model
----------------------------------

This model describes a hydrological model with linear reservoirs used to describe the hillslope surrounding the channel. This is equivalent to a hillslope with a constant runoff. This model is implemented as model 190.

Three states are modeled at every link:

:math:`q(t)`
: Channel discharge [:math:`m^3/s`\ ]

:math:`s_p(t)`
: Water ponded on hillslope surface [:math:`m`\ ]

:math:`s_s(t)`
: Effective water depth in hillslope subsurface [:math:`m`\ ]

where each state is a function of time (:math:`t`), measured in :math:`mins`.

These states are given as the solution to the differential equations

.. math::

  \frac{dq}{dt} &= \frac{1}{\tau} \left(\frac{q}{q_r}\right)^{\lambda_1} \left( -q + (q_{pc} + q_{sc}) \cdot (A_h/60.0) + q_{in}(t) \right) \\
  \frac{ds_p}{dt} &= p(t) \cdot c_1 - q_{pc} - e_p \\
  \frac{ds_s}{dt} &= p(t) \cdot c_2 - q_{sc} - e_s.

Here, precipitation and potential evaporation are given as the time series :math:`p(t)` and :math:`e_{pot}(t)`, measured in :math:`mm/hr` and :math:`mm/month`, respectively. The function :math:`q_{in}(t)` is the total discharge entering the channel from the channels of parent links, measured in :math:`m^3/s`. A flux moves water from the water ponded on the surface to the channel, and another flux moves water from the subsurface to the channel. These are defined by

.. math::

  q_{pc} &= k_2 \cdot s_p \hspace{.2in} [m/min] \\
  q_{sc} &= k_3 \cdot s_s \hspace{.2in} [m/min].

Further fluxes representing evaporation are given by

.. math::

  e_p &= Corr_{evap} \cdot C_p \cdot e_{pot}(t) \cdot u \hspace{.2in} [m/min] \\
  e_s &= Corr_{evap} \cdot C_s \cdot e_{pot}(t) \cdot u \hspace{.2in} [m/min] \\
  Corr_{evap} &= \left\{ \begin{array}{ll} \frac{1}{C_p + C_s}, & \mbox{if } C_p + C_s > 1, \\ 1, & \mbox{else}  \end{array} \right. \\
  C_p &= \frac{s_p}{e_{pot}(t)} \\
  C_s &= \frac{s_s}{e_{pot}(t)}.

When potential evaporation is :math:`0`, the fluxes :math:`e_p` and :math:`e_s` are taken to be :math:`0\ m/min`.

Some values in the equations above are constant in time, and are given by

.. math::

  u &= 10^{-3}/(30\cdot24\cdot60) \\
  k_2 &= v_h \cdot L / A_h \cdot 60 \cdot 10^{-3} \hspace{.2in} [1/min] \\
  k_3 &= v_g \cdot L / A_h \cdot 60 \cdot 10^{-3} \hspace{.2in} [1/min] \\
  \frac{1}{\tau} &= \frac{60 \cdot v_r \cdot (A/A_r)^{\lambda_2}}{(1-\lambda_1) \cdot L \cdot 10^{-3}} \hspace{.2in} [1/min] \\
  c_1 &= RC \cdot (0.001/60) \\
  c_2 &= (1-RC) \cdot (0.001/60) \\
  q_r &= 1 \hspace{.2in} [m^3/s] \\
  A_r &= 1 \hspace{.2in} [km^2].

Several parameters are required for the model. These are constant in time and represent:

:math:`A`
: Total area draining into this link [:math:`km^2`\ ]

:math:`L`
: Channel length of this link [:math:`km`\ ]

:math:`A_h`
: Area of the hillslope of this link [:math:`km^2`\ ].

Finally, some parameters above are constant in time and take the same value at every link. These are:

:math:`v_r`
: Channel reference velocity [:math:`m/s`\ ]

:math:`\lambda_1`
: Exponent of channel velocity discharge []

:math:`\lambda_2`
: Exponent of channel velocity area []

:math:`RC`
: Runoff coefficient []

:math:`v_h`
: Velocity of water on the hillslope [:math:`m/s`\ ]

:math:`v_g`
: Velocity of water in the subsurface [:math:`m/s`\ ].

Let’s walk through the required setup for this model. The above information for the model appears in three different source files: *definetype.c*, *problems.c*, and *problem.h*.

The function *SetParamSizes* contains the block of code for model 190:

::

  GlobalVars->dim = 3;
  GlobalVars->template_flag = 0;
  GlobalVars->assim_flag = 0;
  GlobalVars->diff_start = 0;
  GlobalVars->no_ini_start = GlobalVars->dim;
  num_global_params = 6;
  GlobalVars->uses_dam = 0;
  GlobalVars->params_size = 8;
  GlobalVars->iparams_size = 0;
  GlobalVars->dam_params_size = 0;
  GlobalVars->area_idx = 0;
  GlobalVars->areah_idx = 2;
  GlobalVars->disk_params = 3;
  GlobalVars->num_dense = 1;
  GlobalVars->convertarea_flag = 0;
  GlobalVars->num_forcings = 2;

Each value above is stored into a structure called *GlobalVars*. Details about this object can be found in Section [sec: univvars structure]. Effectively, this object holds the values described in Section [sec: setparamsizes]. *dim* is set to 3, as this is the number of states of the model (:math:`q`, :math:`s_p`, and :math:`s_s`). This value is the size of the state and equation-value vectors. For the ordering in these vectors, we use:

.. math::

  \begin{array}{ccccc}
  \mbox{States:} &  q  &  s_p  &  s_s \\
  \mbox{Index:} & 0 & 1 & 2
  \end{array}

This ordering is not explicitly stated anywhere in code. Anytime a routine in *definetype.c* or *problems.c* accesses values in a state or equation-value vector, the routine’s creator must keep the proper ordering in mind. *template\_flag* is set to 0, as no XML parser is used for the model equations. *assim\_flag* is set to 0 for no data assimilation.

The constant runoff model consists entirely of differential equations (i.e. no algebraic equations), so *diff\_start* can be set to the beginning of the state vector (index 0). *no\_ini\_start* is set to the dimension of the state vector. This means initial conditions for all 3 states must be specified by the source from the global file in the initial values section (see Section [sec: initial states]).

Six parameters are required as input which are uniform amongst all links. This value is stored in *num\_global\_params*. This model does use dams, so the *uses\_dam* flag is set to 0 and *dam\_params\_size* is set to 0.

Each link has parameters which will be stored in memory. Some of these values must be specified as inputs, while others can be computed and stored. For the constant runoff model, these parameters and the order in which we store them is

.. math::

  \begin{array}{ccccccccc}
  \mbox{Parameters:} &  A  &  L  &  A_h  &  k_2  &  k_3  &  invtau  &  c_1  &  c_2  \\
  \mbox{Index:} & 0 & 1 & 2 & 3 & 4 & 5 & 6 & 7
  \end{array}

Each link has 8 parameters and no integer parameters. Thus *params\_size* is set to 8 and *iparams\_size* is set to 0. The parameters :math:`A`, :math:`L`, and :math:`A_h` are required inputs, while the others are computed in terms of the first three parameters and the global parameters. Therefore *disk\_params* is set to 3. The index *area\_idx* is set to 0, as 0 is the index of the upstream area. Similarly, *areah\_idx* is set to 2 for the hillslope area. *convertarea\_flag* is set to 0, as the hillslope area will be converted to units of :math:`m^2`, as shown below.

When passing information from one link to another downstream, only the channel discharge :math:`q` is needed. So we set *num\_dense* to 1. Finally, two forcings are used in the constant runoff model (precipitation and evaporation), so *num\_forcings* is set to 2.

In the *SetParamSizes* routine, an array *dense\_indices* is created with a single element (the size is *num\_dense*). For model 190, the entry is set via:

::

  GlobalVars->dense_indices[0] = 0;   //Discharge

Because the state :math:`q` is passed to other links, its index in state vectors is put into the *dense\_indices* array.

In the routine *ConvertParams*, two parameters are opted to receive a unit conversion:

::

  params->ve[1] *= 1000;  //L: km -> m
  params->ve[2] *= 1e6;   //A_h: km^2 -> m^2

The parameter with index 1 (:math:`L`) is multiplied by 1000 to convert from :math:`km` to :math:`m`. Similarly, the parameter with index 2 (:math:`A_h`) is converted to :math:`km^2` to :math:`m^2`. Although these conversions are optional, the model differential equations contain these conversions explicitly. By converting units now, the conversions do not need to be performed during the evaluation of the differential equations.

In the routine *Precalculations*, each of the parameters for the constant runoff model are calculated at each link. The code for the calculations is:

::

  else if(type == 190)
  {
    double* vals = params->ve;
    double A = params->ve[0];
    double L = params->ve[1];
    double A_h = params->ve[2];
    double v_r = global_params->ve[0];
    double lambda_1 = global_params->ve[1];
    double lambda_2 = global_params->ve[2];
    double RC = global_params->ve[3];
    double v_h = global_params->ve[4];
    double v_g = global_params->ve[5];

    vals[3] = v_h * L / A_h * 60.0;   //k_2
    vals[4] = v_g * L / A_h * 60.0;   //k_3
    vals[5] = 60.0*v_r*pow(A,lambda_2) / ((1.0-lambda_1)*L); //invtau
    vals[6] = RC*(0.001/60.0);    //c_1
    vals[7] = (1.0-RC)*(0.001/60.0);  //c_2
  }

Here, the array of parameters is named *vals* (simply as an abbreviation). The input parameters of the system are extracted (with the conversions from *ConvertParams*), and the remaining parameters are calculated, and saved into the corresponding index in *params*.

In the routine *InitRoutines*, the Runge-Kutta solver is selected based upon whether an explicit or implicit method is requested:

::

  else if(exp_imp == 0)
    link->RKSolver = &ExplicitRKSolver;
  else if(exp_imp == 1)
    link->RKSolver = &RadauRKSolver;

Other routines are set here:

::

  else if(type == 190)
  {
    link->f = &LinearHillslope_MonthlyEvap;
    link->alg = NULL;
    link->state_check = NULL;
    link->CheckConsistency =
    &CheckConsistency_Nonzero_3States;
  }

The routines for the algebraic equations and the system state check are set to *NULL*, as they are not used for this model. The routines for the differential equations and state consistency are found in *problems.c*. The routine for the differential equations is *LinearHillslope\_MonthlyEvap*:

::

  void LinearHillslope_MonthlyEvap
  (double t,VEC* y_i,VEC** y_p,
  unsigned short int numparents,VEC* global_params,
  double* forcing_values,QVSData* qvs,VEC* params,
  IVEC* iparams,int state,unsigned int** upstream,
  unsigned int* numupstream,VEC* ans)
  {
    unsigned short int i;

    double lambda_1 = global_params->ve[1];

    double A_h = params->ve[2];
    double k2 = params->ve[3];
    double k3 = params->ve[4];
    double invtau = params->ve[5];
    double c_1 = params->ve[6];
    double c_2 = params->ve[7];

    double q = y_i->ve[0];      //[m^3/s]
    double s_p = y_i->ve[1];    //[m]
    double s_s = y_i->ve[2];    //[m]

    double q_pc = k2 * s_p;
    double q_sc = k3 * s_s;

    //Evaporation
    double C_p,C_s,C_T,Corr_evap;
    double e_pot = forcing_values[1] * (1e-3/(30.0*24.0*60.0)); //[mm/month] -> [m/min]

    if(e_pot > 0.0)
    {
      C_p = s_p / e_pot;
      C_s = s_s / e_pot;
      C_T = C_p + C_s;
    }
    else
    {
      C_p = 0.0;
      C_s = 0.0;
      C_T = 0.0;
    }

    Corr_evap = (C_T > 1.0) ? 1.0/C_T : 1.0;

    double e_p = Corr_evap * C_p * e_pot;
    double e_s = Corr_evap * C_s * e_pot;

    //Discharge
    ans->ve[0] = -q + (q_pc + q_sc) * A_h/60.0;
    for(i=0;i<numparents;i++)
    ans->ve[0] += y_p[i]->ve[0];
    ans->ve[0] = invtau * pow(q,lambda_1) * ans->ve[0];

    //Hillslope
    ans->ve[1] = forcing_values[0]*c_1 - q_pc - e_p;
    ans->ve[2] = forcing_values[0]*c_2 - q_sc - e_a;
  }

The names of parameters and states match with those defined in the mathematics above. The current states and hillslope parameters are unpacked from the state vector *y\_i* and the vector *params*, respectively. The current precipitation value is available in *forcing\_values[0]* and the current potential evaporation is available in *forcing\_values[1]*. The fluxes :math:`q_{pc}` and :math:`q_{sc}` are calculated and used as *q\_pc* and *q\_sc*, respectively. The evaluation of the right side of the differential equations is stored in the equation-value vector *ans*. The channel discharges for the parent links are found in the array of state vectors *y\_p[i]->ve[0]*, with *i* ranging over the number of parents.

The state consistency routine for the constant runoff model is called *CheckConsistency\_Nonzero\_3States*. It is defined as:

::

  void CheckConsistency_Nonzero_3States(VEC* y,
  VEC* params,VEC* global_params)
  {
    if(y->ve[0] < 1e-14)    y->ve[0] = 1e-14;
    if(y->ve[1] < 0.0)  y->ve[1] = 0.0;
    if(y->ve[2] < 0.0)  y->ve[2] = 0.0;
  }

The hillslope states :math:`s_p` and :math:`s_s` should not take negative values, as each is a linear reservoir. Similarly, the channel discharge :math:`q` decays to 0 exponentially as the fluxes from the hillslope and upstream links goes to 0. However, because of the dependence upon :math:`q^{\lambda_1}` in the equation for :math:`\frac{dq}{dt}`, :math:`q` must be kept away from 0. We therefore force it to never become smaller than :math:`10^{-14}\ m^3/s`. It is worth noting that this restriction on :math:`q` can only work if the absolute error tolerance for :math:`q` is greater than :math:`10^{-14}\ m^3/s`.

Each of these functions must also be declared in *problems.h*:

::

  void LinearHillslope_MonthlyEvap(double t,VEC* y_i,  VEC** y_p,unsigned short int numparents,  VEC* global_params,double* forcing_values,  QVSData* qvs,VEC* params,IVEC* iparams,  int state,unsigned int** upstream,  unsigned int* numupstream,VEC* ans);
  void CheckConsistency_Nonzero_3States(VEC* y,  VEC* params,VEC* global_params);

The routine *ReadInitData* only needs to return a value of 0 for model 190. All states are initialized from through a global file, as no algebraic equations exist for this model, and *no\_ini\_start* is set to *dim*. No state discontinuities are used for this model, so a value of 0 is returned.

Top Layer Hydrological Model
----------------------------

This model describes a hydrological model with nonlinear reservoirs used to describe the hillslope surrounding the channel. It features a layer of topsoil to create a runoff coefficient that varies in time. This model is implemented as model 254. The setup of the top layer model is similar to that of the constant runoff model presented in Section [sec: constant runoff model]. However, the top layer model does make use of additional features.

Seven states are modeled at every link:

:math:`q(t)`
: Channel discharge [:math:`m^3/s`\ ]

:math:`s_p(t)`
: Water ponded on hillslope surface [:math:`m`\ ]

:math:`s_t(t)`
: Effective water depth in the top soil layer [:math:`m`\ ]

:math:`s_s(t)`
: Effective water depth in hillslope subsurface [:math:`m`\ ]

:math:`s_{precip}(t)`
: Total fallen precipitation from time :math:`0` to :math:`t` [:math:`m`\ ]

:math:`V_r(t)`
: Total volume of water from runoff from time :math:`0` to :math:`t` [:math:`m^3`\ ]

:math:`q_b(t)`
: Channel discharge from baseflow [:math:`m^3/s`\ ]

where each state is a function of time (:math:`t`), measured in :math:`mins`.

These states are given as the solution to the differential equations

.. math::

  \frac{dq}{dt} &= \frac{1}{\tau} \left(\frac{q}{q_r}\right)^{\lambda_1} \left( -q + c_2 \cdot (q_{pc} + q_{sc}) + q_{in}(t) \right) \\
  \frac{ds_p}{dt} &= c_1 p(t) - q_{pc} - q_{pt} - e_p \\
  \frac{ds_t}{dt} &= q_{pt} - q_{ts} - e_t \\
  \frac{ds_s}{dt} &= q_{ts} - q_{sc} - e_s \\
  \frac{ds_{precip}}{dt} &= c_1 p(t) \\
  \frac{dV_r}{dt} &= q_{pc} \\
  \frac{dq_b}{dt} &= \frac{v_B}{L} (A_h q_{sc} - 60 \cdot q_b + q_{b,in}(t)).

Here, precipitation and potential evaporation are given as the time series :math:`p(t)` and :math:`e_{pot}(t)`, measured in :math:`mm/hr` and :math:`mm/month`, respectively. The function :math:`q_{in}(t)` is again the total discharge entering the channel from the channels of parent links, measured in :math:`m^3/s`. The function :math:`q_{b,in}(t)` is the total of the parents’ baseflow, measured in [:math:`m^3/s`\ ]. Fluxes move water around the different layers of the hillslope, and other fluxes move water from the hillslope to the channel. These are defined by

.. math::

  q_{pc} &= k_2 s_p \hspace{.2in} [m/min] \\
  q_{pt} &= k_t s_p \hspace{.2in} [m/min] \\
  q_{ts} &= k_i s_t \hspace{.2in} [m/min] \\
  q_{sc} &= k_3 s_s \hspace{.2in} [m/min] \\
  k_t &= k_2 \left(A + B \cdot \left(1-\frac{s_t}{S_L}\right)^{\alpha}\right) \hspace{.2in} [1/min].

Fluxes representing evaporation are given by

.. math::

  e_p &= \frac{\frac{s_p}{s_r} \cdot u \cdot e_{pot}(t)}{Corr} \hspace{.2in} [m/min] \\
  e_t &= \frac{\frac{s_t}{S_L} \cdot u \cdot e_{pot}(t)}{Corr} \hspace{.2in} [m/min] \\
  e_s &= \frac{\frac{s_s}{h_b-S_L} \cdot u \cdot e_{pot}(t)}{Corr} \hspace{.2in} [m/min] \\
  Corr &= \frac{s_p}{s_r} + \frac{s_t}{S_L} + \frac{s_s}{h_b-S_L}.

When potential evaporation is :math:`0` or no water is present in the hillslope, the fluxes :math:`e_p`, :math:`e_t`, and :math:`e_s` are taken to be :math:`0\ m/min`.

Some values in the equations above are given by

.. math::

  u &= 10^{-3}/(30\cdot24\cdot60) \\
  \frac{1}{\tau} &= \frac{60 \cdot v_r \cdot (A_{up}/A_r)^{\lambda_2}}{(1-\lambda_1) \cdot L \cdot 10^{-3}} \hspace{.2in} [1/min] \\
  k_2 &= v_h \cdot L / A_h \cdot 60 \cdot 10^{-3} \hspace{.2in} [1/min] \\
  k_i &= k_2 \beta \hspace{.2in} [1/min] \\
  c_1 &= 0.001 / 60 \\
  c_2 &= A_h / 60 \\
  q_r &= 1 \hspace{.2in} [m^3/s] \\
  A_r &= 1 \hspace{.2in} [km^2] \\
  s_r &= 1 \hspace{.2in} [m].

Several parameters are required for the model. These are constant in time and represent:

:math:`A_{up}`
: Total area draining into this link [:math:`km^2`\ ]

:math:`L`
: Channel length of this link [:math:`km`\ ]

:math:`A_h`
: Area of the hillslope of this link [:math:`km^2`\ ].

Finally, some parameters above are constant in time and take the same value at every link. These are:

:math:`v_r`
: Channel reference velocity [:math:`m/s`\ ]

:math:`\lambda_1`
: Exponent of channel velocity discharge []

:math:`\lambda_2`
: Exponent of channel velocity area []

:math:`v_h`
: Velocity of water on the hillslope [:math:`m/s`\ ]

:math:`k_3`
: Infiltration from subsurface to channel [:math:`1/min`\ ]

:math:`\beta`
: Percentage of infiltration from top soil to subsurface []

:math:`h_b`
: Total hillslope depth [:math:`m`\ ]

:math:`S_L`
: Total topsoil depth [:math:`m`\ ]

:math:`A`
: Surface to topsoil infiltration, additive factor []

:math:`B`
: Surface to topsoil infiltration, multiplicative factor []

:math:`\alpha`
: Surface to topsoil infiltration, exponent factor []

:math:`v_B`
: Channel baseflow velocity [:math:`m/s`\ ].

Much of the required setup for this model is similar to that of the constant runoff coefficient model in Section [sec: constant runoff model]. Only the significant changes will be mentioned here.

Several significant differences occur in the routine for *SetParamSizes*:

::

  GlobalVars->dim = 7;
  GlobalVars->no_ini_start = 4;
  num_global_params = 12;
  GlobalVars->params_size = 8;
  GlobalVars->num_dense = 2;
  GlobalVars->num_forcings = 3;

This model has a total of 7 states. However, initial values for only the first 4 must be provided. The others will be set by the routine *ReadInitData*. Therefore *no\_ini\_start* is taken to be 4. The ordering of the state vectors is given by

.. math::

  \begin{array}{cccccccc}
  \mbox{States:} &  q  &  s_p  & s_t & s_s & q_{precip} & V_r & q_b \\
  \mbox{Index:} & 0 & 1 & 2 & 3 & 4 & 5 & 6
  \end{array}

which means initial conditions for the states :math:`q`, :math:`s_p`, :math:`s_t`, and :math:`s_s` must be provided. For this model, we allow the possibility of a reservoir forcing the channel discharge :math:`q` at a particular hillslope. So *num\_forcings* is set to 3 (i.e. precipitation, potential evaporation, and reservoir forcing). Each link will require 2 states from upstream links: :math:`q` and :math:`q_b`. Accordingly, *num\_dense* is set to 2, and *dense\_indices* is set to

::

  GlobalVars->dense_indices[0] = 0;   //Discharge
  GlobalVars->dense_indices[1] = 6;   //Subsurface

In the routine *InitRoutines*, a special case is considered for links with a reservoir forcing. With no reservoir, the Runge-Kutta solver is unchanged from the constant runoff model. The other routines are set by

::

  if(link->res)
  {
    link->f = &TopLayerHillslope_Reservoirs;
    link->RKSolver = &ForcedSolutionSolver;
  }
  else
    link->f = &TopLayerHillslope_extras;
  link->alg = NULL;
  link->state_check = NULL;
  link->CheckConsistency =
  &CheckConsistency_Nonzero_AllStates_q;

If a reservoir is present, then instead of setting *f* to a routine for evaluating differential equations, it is set to a routine for describing how the forcing is applied:

::

  void TopLayerHillslope_Reservoirs(double t,VEC* y_i,
  VEC** y_p,unsigned short int numparents,
  VEC* global_params,double* forcing_values,
  QVSData* qvs,VEC* params,IVEC* iparams,int state,
  unsigned int** upstream,unsigned int* numupstream,
  VEC* ans)
  {
    ans->ve[0] = forcing_values[2];
    ans->ve[1] = 0.0;
    ans->ve[2] = 0.0;
    ans->ve[3] = 0.0;
    ans->ve[4] = 0.0;
    ans->ve[5] = 0.0;
    ans->ve[6] = 0.0;
  }

All states are taken to be 0, except the channel discharge. This state is set to the current forcing value from the reservoir forcing.

As mentioned earlier, the initial conditions for the last 3 states of the state vector are determined in the routine *ReadInitData*:

::

  y_0->ve[4] = 0.0;
  y_0->ve[5] = 0.0;
  y_0->ve[6] = 0.0;

Clearly, these three states are all initialized to 0.

Linear Reservoir Hydrological Model
-----------------------------------

This model describes a hydrological model with linear reservoirs used to describe the hillslope surrounding the channel. This model includes the ability to replace channel routing with a model for a dam. This model is implemented as model 21.

Four states are modeled at every link:

:math:`q(t)`:
Channel discharge [:math:`m^3/s`\ ]

:math:`S(t)`:
Channel storage [:math:`m^3`\ ]

:math:`S_s(t)`:
Volume of water on the hillslope [:math:`m^3`\ ]

:math:`S_g(t)`:
Volume of water in the hillslope subsurface [:math:`m^3`\ ]

where each state is a function of time (:math:`t`), measured in :math:`mins`.

These states are given as the solution to the differential-algebraic equations

.. math::

  q &= \left\{ \begin{array}{ll} \frac{1}{60 \cdot \tau} (S/S_r)^{1/(1-\lambda_1)} & \mbox{if no dam present} \\
  c_1 r^2 \left( \arccos{(f)} - f \sqrt{1-f^2} - \pi \right) \sqrt{2 g h} & \mbox{if } h < d \\
  c_1 O_a \sqrt{2 g h} & \mbox{if } h < H_{spill} \\
  c_1 O_a \sqrt{2 g h} + c_2 L_{spill} \left(\frac{h - H_{spill}}{H_r}\right)^{3/2} & \mbox{if } h < H_{max} \\
  c_1 O_a \sqrt{2 g h} + c_2 L_{spill} \left(\frac{h - H_{spill}}{H_r}\right)^{3/2} & \\
  \hspace{.5in} + \frac{1}{60 \cdot \tau} (\frac{S-S_{max}}{S_r})^{1/(1-\lambda_1)} & \mbox{if } h > H_{max}
  \end{array} \right. \\
  \frac{dS}{dt} &= k_2 S_s + k_3 S_g - 60 \cdot q + 60 \cdot q_{in} \\
  \frac{dS_s}{dt} &= u RC p(t) A_h - k_2 S_s \\
  \frac{dS_g}{dt} &= u (1-RC) p(t) A_h - k_3 S_g.

Some values in the equations above are given by

.. math::

  u &= 10^{-3}/60 \\
  g &= 9.81 \hspace{.2in} [m/s^2] \\
  \frac{1}{\tau} &= \frac{60 \cdot v_r \cdot (A/A_r)^{\lambda_2}}{(1-\lambda_1) \cdot L \cdot 10^{-3}} \hspace{.2in} [1/min] \\
  k_2 &= v_h \cdot L / A_h \cdot 60 \cdot 10^{-3} \hspace{.2in} [1/min] \\
  k_3 &= v_g \cdot L / A_h \cdot 60 \cdot 10^{-3} \hspace{.2in} [1/min] \\
  O_a &= \frac{\pi}{4} d^2 \hspace{.2in} [m^2] \\
  r &= d/2 \hspace{.2in} [m] \\
  f &= (h-r)/r \hspace{.2in} [] \\
  h &= H_{max} (S/S_{max})^{\alpha} \hspace{.2in} [m] \\
  H_r &= 1 \hspace{.2in} [m] \\
  S_r &= 1 \hspace{.2in} [m^3].

Several parameters are required for the model. These are constant in time and represent:

:math:`A`
: Total area draining into this link [:math:`km^2`\ ]

:math:`L`
: Channel length of this link [:math:`km`\ ]

:math:`A_h`
: Area of the hillslope of this link [:math:`km^2`\ ].

Some parameters above are constant in time and take the same value at every link. These are:

:math:`v_r`
: Channel reference velocity [:math:`m/s`\ ]

:math:`\lambda_1`
: Exponent of channel velocity discharge []

:math:`\lambda_2`
: Exponent of channel velocity area []

:math:`RC`
: Runoff coefficient []

:math:`S_0`
: Initial effective depth of water on the surface and subsurface [:math:`m`\ ]

:math:`v_h`
: Velocity of water on the hillslope [:math:`m/s`\ ]

:math:`v_g`
: Velocity of water in the hillslope subsurface [:math:`m/s`\ ].

Additional parameters are required at links with a dam model:

:math:`H_{spill}`
: Height of the spillway [:math:`m`\ ]

:math:`H_{max}`
: Height of the dam [:math:`m`\ ]

:math:`S_{max}`
: Maximum volume of water the dam can hold [:math:`m^3`\ ]

:math:`\alpha`
: Exponent for bankfull

:math:`d`
: Diameter of dam orifice [:math:`m`\ ]

:math:`c_1`
: Coefficient for discharge from dam

:math:`c_2`
: Coefficient for discharge from dam

:math:`L_{spill}`
: Length of the spillway [:math:`m`\ ].

Every link has 7 local parameters. If a dam is present, 8 additional parameters are required. In the routine *SetParamSizes*, these values are used:

::

  GlobalVars->params_size = 7;
  GlobalVars->dam_params_size = 15;

Discontinuities in the states of the system occur because of the presence of dams. In *InitRoutines*, the appropriate Runge-Kutta solvers are set:

::

  if(type == 21 && dam == 1)
    link->RKSolver = &ExplicitRKIndex1SolverDam;
  else if(type == 21 && dam == 0)
    link->RKSolver = &ExplicitRKIndex1Solver;

Further routines are set:

::

  if(dam)
    link->f = &dam_rain_hillslope;
  else
    link->f = &nodam_rain_hillslope;
  link->alg = &dam_q;
  link->state_check = &dam_check;
  link->CheckConsistency =
  &CheckConsistency_Nonzero_4States;

Two different routines are used for the differential equations, depending upon whether a dam is present at the link. Although one routine could be used, considering separately the links with a dam and those without is more efficient. The possible discontinuity states in which a dam could be are indexed by:

+-------+---------------------------------------------------------------------------+
| Value | Meaning                                                                   |
+=======+===========================================================================+
| 0     | No dam present                                                            |
+-------+---------------------------------------------------------------------------+
| 1     | Water height in the dam is between the orifice diameter and the spillway  |
+-------+---------------------------------------------------------------------------+
| 2     | Water height in the dam is between the spillway and the height of the dam |
+-------+---------------------------------------------------------------------------+
| 3     | Water height in the dam is above the height of the dam                    |
+-------+---------------------------------------------------------------------------+
| 4     | Water height in the dam is below the orifice diameter                     |
+-------+---------------------------------------------------------------------------+

These indices are tracked by the *state\_check* routine:

::

  int dam_check(VEC* y,VEC* global_params,VEC* params,
  QVSData* qvs,unsigned int dam)
  {
    if(dam == 0)    return 0;

    double H_spill = params->ve[7];
    double H_max = params->ve[8];
    double S_max = params->ve[9];
    double alpha = params->ve[10];
    double diam = params->ve[11];
    double S = y->ve[1];
    double h = H_max * pow(S/S_max,alpha);

    if(h < diam)        return 4;
    if(h <= H_spill)    return 1;
    if(h <= H_max)      return 2;
    return 3;
  }

This model also uses an algebraic equation for channel discharge. The routine for this equation is:

::

  void dam_q(VEC* y,VEC* global_params,VEC* params,  QVSData* qvs,int state,VEC* ans)
  {
    double lambda_1 = global_params->ve[1];
    double invtau = params->ve[5];
    double S = (y->ve[1] < 0.0) ? 0.0 : y->ve[1];

    if(state == 0)
      ans->ve[0] = invtau/60.0*pow(S,1.0/(1.0-lambda_1));
    else
    {
      double orifice_area = params->ve[6];
      double H_spill = params->ve[7];
      double H_max = params->ve[8];
      double S_max = params->ve[9];
      double alpha = params->ve[10];
      double diam = params->ve[11];
      double c_1 = params->ve[12];
      double c_2 = params->ve[13];
      double L_spill = params->ve[14];
      double g = 9.81;

      double h = H_max * pow(S/S_max,alpha);
      double diff =
      (h - H_spill >= 0) ? h - H_spill : 0.0;

      if(state == 1)
      ans->ve[0] =
      c_1*orifice_area*pow(2*g*h,.5);
      else if(state == 2)
      ans->ve[0] =
      c_1*orifice_area*pow(2*g*h,.5)
      + c_2*L_spill*pow(diff,1.5);
      else if(state == 3)
      ans->ve[0] =
      c_1*orifice_area*pow(2*g*h,.5)
      + c_2*L_spill*pow(diff,1.5)
      + invtau/60.0
      *pow(S-S_max,1.0/(1.0-lambda_1));
      else //state == 4
      {
        double r = diam/2.0;
        double frac =
        (h < 2*r) ? (h-r)/r : 1.0;
        double A =
        -r*r*(acos(frac)
        - pow(1.0-frac*frac,.5)*frac
        - 3.141592653589);
        ans->ve[0] = c_1*A*pow(2*g*h,.5);
      }
    }
  }

Three initial states must be determined in the routine *ReadInitData*. The initial condition for the algebraic state :math:`q` should be determined with a call to the algebraic equation routine. In addition, the two hillslope states must be set, and the initial state of the dam returned.

::

  double RC = global_params->ve[3];
  double S_0 = global_params->ve[4];
  double A_h = params->ve[2];
  y_0->ve[2] = RC * S_0 * A_h;
  y_0->ve[3] = (1.0 - RC) * S_0 * A_h;

  state = dam_check(y_0,global_params,params,qvs,dam);
  dam_q(y_0,global_params,params,qvs,state,y_0);
  return state;