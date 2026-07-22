-- Migration: Tạo bảng khu_pho (liên kết tỉnh/thành) và dai_dien_khu_pho
-- Chạy script này trong NeonDB SQL Editor trước khi sử dụng chức năng quản lý

BEGIN;

-- Tạo bảng khu_pho (có parent_ten liên kết tới tỉnh/thành)
CREATE TABLE IF NOT EXISTS khu_pho (
  id SERIAL PRIMARY KEY,
  ten_khu_pho VARCHAR(255) NOT NULL,
  mo_ta TEXT,
  dia_chi VARCHAR(255),
  parent_ten VARCHAR(255),  -- Tên tỉnh/thành phố (liên kết từ provinces.name)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tạo bảng dai_dien_khu_pho (đại diện thuộc khu phố)
CREATE TABLE IF NOT EXISTS dai_dien_khu_pho (
  id SERIAL PRIMARY KEY,
  ho_ten VARCHAR(255) NOT NULL,
  so_dien_thoai VARCHAR(20),
  email VARCHAR(255),
  dia_chi TEXT,
  khu_pho_id INTEGER REFERENCES khu_pho(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index để tối ưu tìm kiếm
CREATE INDEX IF NOT EXISTS idx_dai_dien_ho_ten ON dai_dien_khu_pho(ho_ten);
CREATE INDEX IF NOT EXISTS idx_dai_dien_khu_pho_id ON dai_dien_khu_pho(khu_pho_id);
CREATE INDEX IF NOT EXISTS idx_dai_dien_so_dien_thoai ON dai_dien_khu_pho(so_dien_thoai);
CREATE INDEX IF NOT EXISTS idx_dai_dien_email ON dai_dien_khu_pho(email);
CREATE INDEX IF NOT EXISTS idx_khu_pho_parent_ten ON khu_pho(parent_ten);

-- Trigger tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_khu_pho_updated_at ON khu_pho;
CREATE TRIGGER update_khu_pho_updated_at
    BEFORE UPDATE ON khu_pho
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dai_dien_khu_pho_updated_at ON dai_dien_khu_pho;
CREATE TRIGGER update_dai_dien_khu_pho_updated_at
    BEFORE UPDATE ON dai_dien_khu_pho
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Thêm cột parent_ten nếu bảng khu_pho đã tồn tại
ALTER TABLE khu_pho ADD COLUMN IF NOT EXISTS parent_ten VARCHAR(255);

COMMIT;