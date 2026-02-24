
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS UserPostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostWithTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerUserId,
        COALESCE(t.TagName, 'No Tags') AS TagName,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON rp.PostId = t.ExcerptPostId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.UserId) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    wp.Title,
    wp.CreationDate,
    wp.Score,
    wp.ViewCount,
    u.DisplayName,
    u.TotalBounty,
    u.BadgeCount,
    u.AnswerCount,
    wp.TagName
FROM 
    PostWithTags wp
JOIN 
    UserScores u ON wp.OwnerUserId = u.UserId
WHERE 
    wp.Rank <= 5 
    AND u.BadgeCount > 0 
ORDER BY 
    wp.Score DESC, 
    wp.CreationDate DESC;
