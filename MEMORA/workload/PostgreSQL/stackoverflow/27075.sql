
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        unnest(string_to_array(rp.Tags, '>')) AS Tag
    FROM 
        RankedPosts rp
)
SELECT 
    rp.OwnerUserId AS UserId,
    ud.DisplayName,
    ud.Reputation,
    COUNT(tp.Tag) AS TagCount,
    SUM(CASE WHEN rp.Rank = 1 THEN 1 ELSE 0 END) AS LatestQuestionCount,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.Score) AS TotalScore,
    MAX(rp.CreationDate) AS LastActivityDate
FROM 
    RankedPosts rp
JOIN 
    UserDetails ud ON rp.OwnerUserId = ud.UserId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
GROUP BY 
    rp.OwnerUserId, ud.DisplayName, ud.Reputation
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 10;
