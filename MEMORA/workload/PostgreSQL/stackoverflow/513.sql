
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), PopularTags AS (
    SELECT 
        TagName, 
        SUM(Count) AS TotalCount
    FROM 
        Tags
    GROUP BY 
        TagName
    ORDER BY 
        TotalCount DESC
    LIMIT 10
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Ranking
    FROM 
        Users u
), TopContributors AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostsCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days'
    GROUP BY 
        p.OwnerUserId
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ut.DisplayName AS TopContributorName,
    ut.Reputation AS ContributorReputation,
    pt.TagName,
    pt.TotalCount
FROM 
    RecentPosts rp
LEFT JOIN 
    TopContributors tc ON rp.PostId IN (
        SELECT p.Id
        FROM Posts p
        WHERE p.OwnerUserId = tc.OwnerUserId
    )
LEFT JOIN 
    UserReputation ut ON tc.OwnerUserId = ut.UserId
CROSS JOIN 
    PopularTags pt
WHERE 
    rp.Score > 10
ORDER BY 
    rp.Score DESC, 
    pt.TotalCount DESC
LIMIT 20;
