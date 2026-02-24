
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 10), p.CreationDate) AS CloseDate,
        COALESCE(MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 11), NULL) AS ReopenDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        (p.ViewCount > 100 OR p.Score >= 5) 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
TagExcerpts AS (
    SELECT 
        t.TagName,
        p.Id AS PostId,
        p.Title
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON t.ExcerptPostId = p.Id
    WHERE 
        t.IsModeratorOnly IS NULL
),
UserPostRank AS (
    SELECT 
        ps.OwnerUserId AS UserId,
        COUNT(ps.Id) AS TotalPosts,
        RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY COUNT(ps.Id) DESC) AS PostRank
    FROM 
        Posts ps
    GROUP BY 
        ps.OwnerUserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpVotesCount,
        us.DownVotesCount,
        pa.PostId,
        pa.Title,
        pa.Score,
        pa.CloseDate,
        pa.ReopenDate,
        te.TagName,
        up.TotalPosts,
        up.PostRank
    FROM 
        UserStats us
    LEFT JOIN 
        PostActivity pa ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pa.PostId)
    LEFT JOIN 
        TagExcerpts te ON pa.PostId = te.PostId
    LEFT JOIN 
        UserPostRank up ON us.UserId = up.UserId 
    WHERE 
        us.Rank <= 10
        AND (pa.CloseDate IS NULL OR pa.ReopenDate IS NOT NULL)
)
SELECT 
    DisplayName AS "User",
    Reputation,
    UpVotesCount AS "Total Upvotes",
    DownVotesCount AS "Total Downvotes",
    Title AS "Post Title",
    Score AS "Post Score",
    TagName AS "Associated Tag",
    TotalPosts AS "Posts Total",
    PostRank AS "Post Rank"
FROM 
    FinalStats
ORDER BY 
    Reputation DESC, Score DESC;
