function outputCoeff = shift_formants(inputCoeff, shiftRatio, fs)
%shift the first 3 formants of inputCoeff by shiftRatio
% inputCoeff: A vector of LPC coefficients
% shiftRatio: (float) amount to shift the formants by
% outputCoeff: A vector of LPC coefficients with the first 3 formants shifted by shiftRatio
% fs: sampling rate
    poles = roots(inputCoeff);
    arguments = angle(poles);
    moduli = abs(poles);
    tmp_matrix_all = [poles arguments moduli]; % this stores all poles, arguments and moduli (all conjugate pairs are stored)
    qq = (arguments > 0); % find those with their angles between 0 and pi
    poles = poles(qq);
    arguments = arguments(qq);
    moduli = moduli(qq);
    tmp_matrix = [poles arguments moduli];
    tmp_matrix = sortrows(tmp_matrix,2);
    f1 = tmp_matrix(1,2)/pi*fs/2; % 1st formant
    f2 = tmp_matrix(2,2)/pi*fs/2; % 2nd formant
    f3 = tmp_matrix(3,2)/pi*fs/2; % 3rd formant

    % modify f1, f2, f3
    f1_new = f1 * shiftRatio;
    f2_new = f2 * shiftRatio;
    f3_new = f3 * shiftRatio;
    % get angles of new f1 and f2
    angle_f1 = f1_new / fs * 2 * pi;
    angle_f2 = f2_new / fs * 2 * pi;
    angle_f3 = f3_new / fs * 2 * pi;
    % find the root pairs in original poles
    f1_ind = find(tmp_matrix_all(:,1) == tmp_matrix(1,1));
    f1_ind_conj = find(tmp_matrix_all(:,1) == conj(tmp_matrix(1,1)));
    f2_ind = find(tmp_matrix_all(:,1) == tmp_matrix(2,1));
    f2_ind_conj = find(tmp_matrix_all(:,1) == conj(tmp_matrix(2,1)));
    f3_ind = find(tmp_matrix_all(:,1) == tmp_matrix(3,1));
    f3_ind_conj = find(tmp_matrix_all(:,1) == conj(tmp_matrix(3,1)));
    % get the new poles
    pole_f1 = tmp_matrix_all(f1_ind,3) * exp(1i * angle_f1);
    pole_f2 = tmp_matrix_all(f2_ind,3) * exp(1i * angle_f2);
    pole_f3 = tmp_matrix_all(f3_ind,3) * exp(1i * angle_f3);
    % replace the original poles with new poles
    tmp_matrix_all(f1_ind,1) = pole_f1;
    tmp_matrix_all(f1_ind_conj,1) = conj(pole_f1);
    tmp_matrix_all(f2_ind,1) = pole_f2;
    tmp_matrix_all(f2_ind_conj,1) = conj(pole_f2);
    tmp_matrix_all(f3_ind,1) = pole_f3;
    tmp_matrix_all(f3_ind_conj,1) = conj(pole_f3);
    % get the new A
    new_poles = tmp_matrix_all(:,1);
    outputCoeff = poly(new_poles);
end