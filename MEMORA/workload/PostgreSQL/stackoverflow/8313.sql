WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostsCreated, 
        SUM(v.BountyAmount) AS TotalBounties 
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        COUNT(p.Id) > 5
),
PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.Upvotes, 
        rp.Downvotes, 
        ua.UserId, 
        ua.DisplayName AS UserDisplayName, 
        pt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId LIMIT 1)
    LEFT JOIN 
        PopularTags pt ON pt.PostCount > 10
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.Upvotes,
    pd.Downvotes,
    pd.UserDisplayName,
    STRING_AGG(DISTINCT pt.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    Tags pt ON p.Tags LIKE CONCAT('%', pt.TagName, '%')
GROUP BY 
    pd.Title, pd.CreationDate, pd.Score, pd.ViewCount, pd.Upvotes, pd.Downvotes, pd.UserDisplayName
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
LIMIT 10;