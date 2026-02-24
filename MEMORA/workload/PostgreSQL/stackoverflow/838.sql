WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        r.PostId, 
        r.Title, 
        r.Score, 
        r.CreationDate, 
        r.OwnerDisplayName
    FROM 
        RankedPosts r
    WHERE 
        r.PostRank = 1
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostsWithComments AS (
    SELECT 
        t.PostId,
        t.Title,
        t.Score,
        t.CreationDate,
        t.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopPosts t
    LEFT JOIN 
        PostComments pc ON t.PostId = pc.PostId
),
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FinalResult AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerDisplayName,
        p.CommentCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        (p.Score + COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0)) AS NetScore
    FROM 
        PostsWithComments p
    LEFT JOIN 
        VotesSummary vs ON p.PostId = vs.PostId
)
SELECT 
    *,
    CASE 
        WHEN NetScore > 100 THEN 'High Engagement'
        WHEN NetScore BETWEEN 51 AND 100 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FinalResult
ORDER BY 
    NetScore DESC, CreationDate DESC;