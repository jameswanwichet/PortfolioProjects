

-- Cleaning Data in SQL Queries

SELECT * FROM `nashville housing data for data cleaning`;

-- 1. Standardize Data Format

SELECT SaleDate, STR_TO_DATE(SaleDate, '%M %e, %Y') AS ConvertedSaleDate
FROM `nashville housing data for data cleaning`;

UPDATE `nashville housing data for data cleaning`
SET SaleDate = STR_TO_DATE(SaleDate, '%M %e, %Y');

-- 2. Populate Property Address data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM `nashville housing data for data cleaning` AS a
JOIN `nashville housing data for data cleaning` AS b
    ON a.ParcelID = b.ParcelID
    AND a.`UniqueID` <> b.`UniqueID`
WHERE b.PropertyAddress IS NULL;

UPDATE `nashville housing data for data cleaning` AS a 
JOIN `nashville housing data for data cleaning` AS b 
ON a.ParcelID = b.ParcelID AND a.`UniqueID` <> b.`UniqueID` 
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress) 
WHERE b.PropertyAddress IS NULL;


-- 3. Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM `nashville housing data for data cleaning`;

SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address1,
       SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS Address2
FROM `nashville housing data for data cleaning`;


ALTER TABLE `nashville housing data for data cleaning`
ADD PropertySplitAddress CHAR(255) CHARACTER SET UTF8MB4;

UPDATE `nashville housing data for data cleaning`
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);

ALTER TABLE `nashville housing data for data cleaning`
ADD PropertySplitCity CHAR(255) CHARACTER SET UTF8MB4;

UPDATE `nashville housing data for data cleaning`
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));


SELECT SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1) AS Address1,
       SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 2), '.', -1) AS Address2,
       SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1) AS Address3
FROM `nashville housing data for data cleaning`;

ALTER TABLE `nashville housing data for data cleaning`
ADD OwnerSplitAddress CHAR(255) CHARACTER SET UTF8MB4;

UPDATE `nashville housing data for data cleaning`
SET OwnerSplitAddress = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1) ;

ALTER TABLE `nashville housing data for data cleaning`
ADD OwnerSplitCity CHAR(255) CHARACTER SET UTF8MB4;

UPDATE `nashville housing data for data cleaning`
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 2), '.', -1) ;

ALTER TABLE `nashville housing data for data cleaning`
ADD OwnerSplitState CHAR(255) CHARACTER SET UTF8MB4;

UPDATE `nashville housing data for data cleaning`
SET OwnerSplitState = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1) ;



-- Change Y and N to Yes and No in 'Sold as Vacant' field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM `nashville housing data for data cleaning`
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant END AS SoldAsVacant_Updated
FROM `nashville housing data for data cleaning`;

UPDATE `nashville housing data for data cleaning`
SET SoldAsVacant =
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant END;

-- Remove Duplicates 

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice, 
                SaleDate, 
                LegalReference
    ORDER BY UniqueID
    ) row_num
FROM `nashville housing data for data cleaning`
)
DELETE FROM `nashville housing data for data cleaning`
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowNumCTE
    WHERE row_num > 1
);
 
 WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				PropertyAddress,
                SalePrice, 
                SaleDate, 
                LegalReference
    ORDER BY 
					UniqueID
    ) row_num
FROM `nashville housing data for data cleaning`)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


-- Delete Unused Columns

SELECT * 
FROM `nashville housing data for data cleaning`;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN OwnerAddress;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN TaxDistrict;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN PropertyAddress;

ALTER TABLE `nashville housing data for data cleaning`
DROP COLUMN SaleDate;
