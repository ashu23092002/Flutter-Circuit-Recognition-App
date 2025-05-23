// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for ngSpice shared library.
class NgSpiceBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NgSpiceBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NgSpiceBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  int ngSpice_Init(
    ffi.Pointer<SendChar> printfcn,
    ffi.Pointer<SendStat> statfcn,
    ffi.Pointer<ControlledExit> ngexit,
    ffi.Pointer<SendData> sdata,
    ffi.Pointer<SendInitData> sinitdata,
    ffi.Pointer<BGThreadRunning> bgtrun,
    ffi.Pointer<ffi.Void> userData,
  ) {
    return _ngSpice_Init(
      printfcn,
      statfcn,
      ngexit,
      sdata,
      sinitdata,
      bgtrun,
      userData,
    );
  }

  late final _ngSpice_InitPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<SendChar>,
              ffi.Pointer<SendStat>,
              ffi.Pointer<ControlledExit>,
              ffi.Pointer<SendData>,
              ffi.Pointer<SendInitData>,
              ffi.Pointer<BGThreadRunning>,
              ffi.Pointer<ffi.Void>)>>('ngSpice_Init');
  late final _ngSpice_Init = _ngSpice_InitPtr.asFunction<
      int Function(
          ffi.Pointer<SendChar>,
          ffi.Pointer<SendStat>,
          ffi.Pointer<ControlledExit>,
          ffi.Pointer<SendData>,
          ffi.Pointer<SendInitData>,
          ffi.Pointer<BGThreadRunning>,
          ffi.Pointer<ffi.Void>)>();

  int ngSpice_Init_Sync(
    ffi.Pointer<GetVSRCData> vsrcdat,
    ffi.Pointer<GetISRCData> isrcdat,
    ffi.Pointer<GetSyncData> syncdat,
    ffi.Pointer<ffi.Int> ident,
    ffi.Pointer<ffi.Void> userData,
  ) {
    return _ngSpice_Init_Sync(
      vsrcdat,
      isrcdat,
      syncdat,
      ident,
      userData,
    );
  }

  late final _ngSpice_Init_SyncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<GetVSRCData>,
              ffi.Pointer<GetISRCData>,
              ffi.Pointer<GetSyncData>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Void>)>>('ngSpice_Init_Sync');
  late final _ngSpice_Init_Sync = _ngSpice_Init_SyncPtr.asFunction<
      int Function(
          ffi.Pointer<GetVSRCData>,
          ffi.Pointer<GetISRCData>,
          ffi.Pointer<GetSyncData>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Void>)>();

  int ngSpice_Command(
    ffi.Pointer<ffi.Char> command,
  ) {
    return _ngSpice_Command(
      command,
    );
  }

  late final _ngSpice_CommandPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<ffi.Char>)>>(
          'ngSpice_Command');
  late final _ngSpice_Command =
      _ngSpice_CommandPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  pvector_info ngGet_Vec_Info(
    ffi.Pointer<ffi.Char> vecname,
  ) {
    return _ngGet_Vec_Info(
      vecname,
    );
  }

  late final _ngGet_Vec_InfoPtr =
      _lookup<ffi.NativeFunction<pvector_info Function(ffi.Pointer<ffi.Char>)>>(
          'ngGet_Vec_Info');
  late final _ngGet_Vec_Info = _ngGet_Vec_InfoPtr
      .asFunction<pvector_info Function(ffi.Pointer<ffi.Char>)>();

  int ngSpice_Circ(
    ffi.Pointer<ffi.Pointer<ffi.Char>> circarray,
  ) {
    return _ngSpice_Circ(
      circarray,
    );
  }

  late final _ngSpice_CircPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Pointer<ffi.Char>>)>>('ngSpice_Circ');
  late final _ngSpice_Circ = _ngSpice_CircPtr
      .asFunction<int Function(ffi.Pointer<ffi.Pointer<ffi.Char>>)>();

  ffi.Pointer<ffi.Char> ngSpice_CurPlot() {
    return _ngSpice_CurPlot();
  }

  late final _ngSpice_CurPlotPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'ngSpice_CurPlot');
  late final _ngSpice_CurPlot =
      _ngSpice_CurPlotPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  ffi.Pointer<ffi.Pointer<ffi.Char>> ngSpice_AllPlots() {
    return _ngSpice_AllPlots();
  }

  late final _ngSpice_AllPlotsPtr = _lookup<
          ffi.NativeFunction<ffi.Pointer<ffi.Pointer<ffi.Char>> Function()>>(
      'ngSpice_AllPlots');
  late final _ngSpice_AllPlots = _ngSpice_AllPlotsPtr
      .asFunction<ffi.Pointer<ffi.Pointer<ffi.Char>> Function()>();

  ffi.Pointer<ffi.Pointer<ffi.Char>> ngSpice_AllVecs(
    ffi.Pointer<ffi.Char> plotname,
  ) {
    return _ngSpice_AllVecs(
      plotname,
    );
  }

  late final _ngSpice_AllVecsPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Pointer<ffi.Char>> Function(
              ffi.Pointer<ffi.Char>)>>('ngSpice_AllVecs');
  late final _ngSpice_AllVecs = _ngSpice_AllVecsPtr.asFunction<
      ffi.Pointer<ffi.Pointer<ffi.Char>> Function(ffi.Pointer<ffi.Char>)>();

  bool ngSpice_running() {
    return _ngSpice_running();
  }

  late final _ngSpice_runningPtr =
      _lookup<ffi.NativeFunction<ffi.Bool Function()>>('ngSpice_running');
  late final _ngSpice_running =
      _ngSpice_runningPtr.asFunction<bool Function()>();

  bool ngSpice_SetBkpt(
    double time,
  ) {
    return _ngSpice_SetBkpt(
      time,
    );
  }

  late final _ngSpice_SetBkptPtr =
      _lookup<ffi.NativeFunction<ffi.Bool Function(ffi.Double)>>(
          'ngSpice_SetBkpt');
  late final _ngSpice_SetBkpt =
      _ngSpice_SetBkptPtr.asFunction<bool Function(double)>();

  int ngSpice_nospinit() {
    return _ngSpice_nospinit();
  }

  late final _ngSpice_nospinitPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('ngSpice_nospinit');
  late final _ngSpice_nospinit =
      _ngSpice_nospinitPtr.asFunction<int Function()>();

  int ngSpice_nospiceinit() {
    return _ngSpice_nospiceinit();
  }

  late final _ngSpice_nospiceinitPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('ngSpice_nospiceinit');
  late final _ngSpice_nospiceinit =
      _ngSpice_nospiceinitPtr.asFunction<int Function()>();
}

final class ngcomplex extends ffi.Struct {
  @ffi.Double()
  external double cx_real;

  @ffi.Double()
  external double cx_imag;
}

typedef ngcomplex_t = ngcomplex;

final class vector_info extends ffi.Struct {
  external ffi.Pointer<ffi.Char> v_name;

  @ffi.Int()
  external int v_type;

  @ffi.Short()
  external int v_flags;

  external ffi.Pointer<ffi.Double> v_realdata;

  external ffi.Pointer<ngcomplex_t> v_compdata;

  @ffi.Int()
  external int v_length;
}

typedef pvector_info = ffi.Pointer<vector_info>;

final class vecvalues extends ffi.Struct {
  external ffi.Pointer<ffi.Char> name;

  @ffi.Double()
  external double creal;

  @ffi.Double()
  external double cimag;

  @ffi.Bool()
  external bool is_scale;

  @ffi.Bool()
  external bool is_complex;
}

typedef pvecvalues = ffi.Pointer<vecvalues>;

final class vecvaluesall extends ffi.Struct {
  @ffi.Int()
  external int veccount;

  @ffi.Int()
  external int vecindex;

  external ffi.Pointer<pvecvalues> vecsa;
}

typedef pvecvaluesall = ffi.Pointer<vecvaluesall>;

final class vecinfo extends ffi.Struct {
  @ffi.Int()
  external int number;

  external ffi.Pointer<ffi.Char> vecname;

  @ffi.Bool()
  external bool is_real;

  external ffi.Pointer<ffi.Void> pdvec;

  external ffi.Pointer<ffi.Void> pdvecscale;
}

typedef pvecinfo = ffi.Pointer<vecinfo>;

final class vecinfoall extends ffi.Struct {
  external ffi.Pointer<ffi.Char> name;

  external ffi.Pointer<ffi.Char> title;

  external ffi.Pointer<ffi.Char> date;

  external ffi.Pointer<ffi.Char> type;

  @ffi.Int()
  external int veccount;

  external ffi.Pointer<pvecinfo> vecs;
}

typedef pvecinfoall = ffi.Pointer<vecinfoall>;
typedef SendChar = ffi.NativeFunction<
    ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef SendStat = ffi.NativeFunction<
    ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef ControlledExit = ffi.NativeFunction<
    ffi.Int Function(
        ffi.Int, ffi.Bool, ffi.Bool, ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef SendData = ffi.NativeFunction<
    ffi.Int Function(pvecvaluesall, ffi.Int, ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef SendInitData = ffi.NativeFunction<
    ffi.Int Function(pvecinfoall, ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef BGThreadRunning = ffi
    .NativeFunction<ffi.Int Function(ffi.Bool, ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef GetVSRCData = ffi.NativeFunction<
    ffi.Int Function(ffi.Pointer<ffi.Double>, ffi.Double, ffi.Pointer<ffi.Char>,
        ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef GetISRCData = ffi.NativeFunction<
    ffi.Int Function(ffi.Pointer<ffi.Double>, ffi.Double, ffi.Pointer<ffi.Char>,
        ffi.Int, ffi.Pointer<ffi.Void>)>;
typedef GetSyncData = ffi.NativeFunction<
    ffi.Int Function(ffi.Double, ffi.Pointer<ffi.Double>, ffi.Double, ffi.Int,
        ffi.Int, ffi.Int, ffi.Pointer<ffi.Void>)>;
