
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM
        Posts p
    JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag_name ON true
    JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
PostRevisions AS (
    SELECT 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate, 
        ph.Comment, 
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deleted'
            ELSE 'Other'
        END AS ActionType
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.ViewCount,
    pt.TagCount,
    ur.UserId,
    ur.DisplayName,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ARRAY_AGG(DISTINCT pr.ActionType) AS RevisionActions,
    COUNT(pr.Comment) AS RevisionComments
FROM 
    Posts p
JOIN 
    PostTagCounts pt ON p.Id = pt.PostId
JOIN 
    PostRevisions pr ON p.Id = pr.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserStatistics ur ON u.Id = ur.UserId
WHERE 
    p.CreationDate >= DATE '2022-01-01'  
GROUP BY 
    p.Id, p.Title, p.Body, p.ViewCount, pt.TagCount, ur.UserId, ur.DisplayName, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges
ORDER BY 
    p.ViewCount DESC
LIMIT 10;
