
WITH UserBadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pb.BadgeCount, 0) AS OwnerBadgeCount,
        COALESCE(pb.BadgeNames, 'None') AS OwnerBadges,
        EXTRACT(EPOCH FROM TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate) AS AgeInSeconds,
        ARRAY_LENGTH(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadgeCounts pb ON u.Id = pb.UserId
    WHERE 
        p.PostTypeId = 1 
),
AggregatedData AS (
    SELECT 
        pd.PostId, 
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.OwnerDisplayName,
        pd.OwnerBadgeCount,
        pd.OwnerBadges,
        pd.AgeInSeconds,
        pd.TagCount,
        CASE 
            WHEN pd.AgeInSeconds < 3600 THEN 'New'
            WHEN pd.AgeInSeconds < 86400 THEN 'Moderate'
            ELSE 'Old'
        END AS PostAgeCategory
    FROM 
        PostDetails pd
)
SELECT 
    PostAgeCategory,
    COUNT(*) AS PostCount,
    AVG(ViewCount) AS AverageViews,
    AVG(OwnerBadgeCount) AS AverageBadges
FROM 
    AggregatedData
GROUP BY 
    PostAgeCategory
ORDER BY 
    PostAgeCategory DESC;
