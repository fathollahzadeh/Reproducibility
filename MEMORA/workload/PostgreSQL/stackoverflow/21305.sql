WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsVotedOn,
        COUNT(DISTINCT b.Id) AS BadgesReceived
    FROM 
        Users u
    LEFT OUTER JOIN Votes v ON u.Id = v.UserId
    LEFT OUTER JOIN Posts p ON v.PostId = p.Id
    LEFT OUTER JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),

PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COALESCE(CC.CommentCount, 0) AS CommentCount,
        COALESCE(PH.EditCount, 0) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN ( 
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY PostId
    ) CC ON p.Id = CC.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS EditCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (4, 5, 6, 10, 13)
        GROUP BY PostId
    ) PH ON p.Id = PH.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    s.UpVotesCount,
    s.DownVotesCount,
    s.PostsVotedOn,
    s.BadgesReceived,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.EditCount,
    GREATEST(0, s.UpVotesCount - s.DownVotesCount) AS NetVotes,
    CASE 
        WHEN ps.RecentPostRank <= 5 THEN 'Recent'
        ELSE 'Older'
    END AS PostRecency,
    COALESCE(t.TagName, 'No Tags') AS Tags
FROM 
    UserVoteSummary s
JOIN 
    Users u ON u.Id = s.UserId
LEFT JOIN 
    PostSummary ps ON ps.RecentPostRank <= 5
LEFT JOIN 
    Tags t ON ps.PostId = t.ExcerptPostId
WHERE 
    (s.PostsVotedOn > 0 OR s.BadgesReceived > 0)
    AND u.Reputation IS NOT NULL
    AND (LOWER(u.Location) LIKE '%remote%' OR u.Location IS NULL)
ORDER BY 
    u.Reputation DESC, ps.CommentCount DESC;