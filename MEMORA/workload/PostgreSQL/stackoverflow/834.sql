
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AcceptedAnswerId, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
), PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
), UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(v.BountyAmount) AS TotalBounty, 
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title, 
    rp.CommentCount, 
    COALESCE(pt.PostCount, 0) AS PopularTagCount, 
    us.DisplayName, 
    us.TotalBounty, 
    us.AvgReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title ILIKE CONCAT('%', pt.TagName, '%')
JOIN 
    UserStatistics us ON us.UserId = rp.AcceptedAnswerId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
