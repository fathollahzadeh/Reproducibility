
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        p.Score > 0 
), 
TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount, 
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>') 
    GROUP BY 
        t.TagName
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        COUNT(DISTINCT v.Id) AS VotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, 
        u.DisplayName
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.OwnerDisplayName, 
    ts.TagName, 
    ts.PostCount, 
    ts.TotalScore, 
    ua.UserId, 
    ua.DisplayName AS UserName, 
    ua.PostsCreated, 
    ua.TotalBadgeClass, 
    ua.VotesReceived
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON rp.Title LIKE CONCAT('%', ts.TagName, '%') 
JOIN 
    UserActivity ua ON rp.OwnerDisplayName = ua.DisplayName
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Rank, 
    ts.TotalScore DESC;
