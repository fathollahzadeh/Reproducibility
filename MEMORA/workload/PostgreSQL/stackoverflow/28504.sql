
WITH TagStats AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserBadgeCounts AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.OwnerUserId
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    ph.LastEditDate,
    tt.Tag,
    tt.PostCount
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryStats ph ON u.Id = ph.OwnerUserId
JOIN 
    TopTags tt ON tt.Rank <= 5  
WHERE 
    u.Reputation > 1000  
ORDER BY 
    u.Reputation DESC, 
    tt.PostCount DESC;
