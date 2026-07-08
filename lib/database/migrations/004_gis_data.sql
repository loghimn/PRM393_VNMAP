-- GIS Data tables: public places, historical places, roads

-- Public places
CREATE TABLE IF NOT EXISTS dia_diem_cong_cong (
    id SERIAL PRIMARY KEY,
    ten VARCHAR(255) NOT NULL,
    loai VARCHAR(100),
    dia_chi TEXT,
    kinh_do DECIMAL(10, 7),
    vi_do DECIMAL(10, 7),
    mo_ta TEXT,
    ghi_chu TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dia_diem_cong_cong_loai ON dia_diem_cong_cong(loai);
CREATE INDEX IF NOT EXISTS idx_dia_diem_cong_cong_kinh_do ON dia_diem_cong_cong(kinh_do);
CREATE INDEX IF NOT EXISTS idx_dia_diem_cong_cong_vi_do ON dia_diem_cong_cong(vi_do);

-- Historical places
CREATE TABLE IF NOT EXISTS dia_diem_lich_su (
    id SERIAL PRIMARY KEY,
    ten VARCHAR(255) NOT NULL,
    loai_di_tich VARCHAR(100),
    dia_chi TEXT,
    kinh_do DECIMAL(10, 7),
    vi_do DECIMAL(10, 7),
    mo_ta TEXT,
    thoi_ky VARCHAR(100),
    ghi_chu TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dia_diem_lich_su_loai_di_tich ON dia_diem_lich_su(loai_di_tich);
CREATE INDEX IF NOT EXISTS idx_dia_diem_lich_su_kinh_do ON dia_diem_lich_su(kinh_do);
CREATE INDEX IF NOT EXISTS idx_dia_diem_lich_su_vi_do ON dia_diem_lich_su(vi_do);

-- Roads
CREATE TABLE IF NOT EXISTS tuyen_duong (
    id SERIAL PRIMARY KEY,
    ten VARCHAR(255) NOT NULL,
    loai VARCHAR(100),
    dia_diem_bat_dau TEXT,
    dia_diem_ket_thuc TEXT,
    chieu_dai DECIMAL(8, 2),
    mo_ta TEXT,
    ghi_chu TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tuyen_duong_loai ON tuyen_duong(loai);