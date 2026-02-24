WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount
),
MostCommentedPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerUserId, 
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        CommentCount > (
            SELECT AVG(CommentCount)
            FROM RankedPosts
        )
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgePoints,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalBenchmark AS (
    SELECT 
        p.Title,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Unknown User') AS DisplayName,
        p.UpVotes - p.DownVotes AS NetVotes
    FROM 
        MostCommentedPosts p
    LEFT JOIN 
        UserStats u ON p.OwnerUserId = u.UserId
    WHERE 
        p.ViewCount > 0
)
SELECT 
    Title,
    CommentCount,
    DisplayName,
    NetVotes,
    CASE
        WHEN NetVotes > 0 THEN 'Positive Interaction'
        WHEN NetVotes < 0 THEN 'Negative Interaction'
        ELSE 'Neutral Interaction'
    END AS InteractionType
FROM 
    FinalBenchmark
ORDER BY 
    NetVotes DESC, CommentCount DESC
LIMIT 100;
