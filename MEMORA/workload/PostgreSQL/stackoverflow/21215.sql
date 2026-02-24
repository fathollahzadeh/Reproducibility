
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.CommentCount,
        p.HistoryCount
    FROM 
        PostActivity p
    WHERE 
        p.ViewCount > (
            SELECT 
                AVG(ViewCount) 
            FROM 
                Posts
        )
        OR p.CommentCount > 5
        OR EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = p.PostId 
            AND v.VoteTypeId = 2
            GROUP BY v.PostId 
            HAVING COUNT(v.Id) > 10
        )
)
SELECT 
    u.UserId,
    u.DisplayName,
    COUNT(DISTINCT fp.PostId) AS ActivePostCount,
    SUM(fp.ViewCount) AS TotalViews,
    COALESCE(SUM(fp.CommentCount), 0) AS TotalComments,
    COALESCE(SUM(fp.HistoryCount), 0) AS TotalHistoryEntries
FROM 
    UserVoteSummary u
JOIN 
    FilteredPosts fp ON u.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE PostTypeId IN (1, 2, 7) 
    )
GROUP BY 
    u.UserId, u.DisplayName
HAVING 
    SUM(fp.ViewCount) > 1000 
ORDER BY 
    TotalViews DESC
LIMIT 10;
