
WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(ARRAY_AGG(t.TagName), ARRAY[]::text[]) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName
         FROM Posts) t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.AnswerCount, p.CommentCount
),
VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT UserId) AS UniqueVoters
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS ClosedDate,
        MAX(CASE WHEN PostHistoryTypeId = 11 THEN CreationDate END) AS ReopenedDate
    FROM 
        PostHistory
    GROUP BY 
        PostId
),
CombinedStats AS (
    SELECT 
        rps.PostId,
        rps.Title,
        rps.Score,
        rps.AnswerCount,
        rps.CommentCount,
        rps.Tags,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        cs.ClosedDate,
        cs.ReopenedDate
    FROM 
        RecentPostStats rps
    LEFT JOIN 
        VoteStats vs ON rps.PostId = vs.PostId
    LEFT JOIN 
        ClosedPosts cs ON rps.PostId = cs.PostId
    WHERE 
        (cs.ClosedDate IS NULL OR (cs.ReopenedDate IS NOT NULL AND cs.ReopenedDate > cs.ClosedDate))
)

SELECT 
    c.PostId,
    c.Title,
    c.Score,
    c.AnswerCount,
    c.CommentCount,
    c.Tags,
    c.UpVotes,
    c.DownVotes,
    CASE 
        WHEN c.ClosedDate IS NOT NULL AND c.ReopenedDate IS NOT NULL THEN 'Reopened'
        WHEN c.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    CombinedStats c
WHERE 
    (c.UpVotes - c.DownVotes) > 5
ORDER BY 
    COALESCE(c.Score, 0) DESC, c.PostId ASC;
