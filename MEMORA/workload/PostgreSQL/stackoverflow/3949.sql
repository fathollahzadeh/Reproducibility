WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        U.DisplayName AS OwnerDisplayName, 
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        AnswerCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
VotesSummary AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostsWithVoteCounts AS (
    SELECT 
        t.PostId, 
        t.Title, 
        t.Score, 
        t.ViewCount, 
        t.AnswerCount, 
        t.OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes, 
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        TopRankedPosts t
    LEFT JOIN 
        VotesSummary v ON t.PostId = v.PostId
),
CombinedResults AS (
    SELECT 
        p.PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.OwnerDisplayName, 
        p.UpVotes, 
        p.DownVotes,
        'Top Posts' AS Category
    FROM 
        PostsWithVoteCounts p
    UNION ALL
    SELECT 
        NULL AS PostId, 
        NULL AS Title, 
        NULL AS Score, 
        NULL AS ViewCount, 
        NULL AS AnswerCount, 
        NULL AS OwnerDisplayName, 
        SUM(v.UpVotes) AS UpVotes, 
        SUM(v.DownVotes) AS DownVotes,
        'Summary' AS Category
    FROM 
        VotesSummary v 
)
SELECT 
    PostId, 
    Title, 
    Score, 
    ViewCount, 
    AnswerCount, 
    OwnerDisplayName, 
    UpVotes, 
    DownVotes, 
    Category
FROM 
    CombinedResults
ORDER BY 
    Category DESC, 
    Score DESC NULLS LAST
LIMIT 20;