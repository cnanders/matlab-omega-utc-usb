[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add package
addpath(genpath(fullfile(cDirThis, '..', 'src')));

inst = omega.UTCUSB(...
    'cPort', 'COM4' ...
);

inst.init();
inst.connect();
st = inst.getModelAndFirmware()
c = inst.getThermocoupleType()
dC = inst.getTemperatureC()
dF = inst.getTemperatureF()
dCFromF = inst.farenheightToCelcius(dF)
inst.disconnect();
delete(inst);
