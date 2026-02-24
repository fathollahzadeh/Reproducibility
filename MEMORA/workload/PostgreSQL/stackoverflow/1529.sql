WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        ScoreRank,
        CommentCount,
        OwnerDisplayName,
        AcceptedAnswer
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    ts.UpVotes,
    ts.DownVotes,
    CASE 
        WHEN tp.AcceptedAnswer > 0 THEN 
            'Accepted Answer Exists'
        ELSE 
            'No Accepted Answer'
    END AS AcceptedAnswerStatus,
    CASE 
        WHEN tp.CommentCount > 5 THEN 
            'Highly Discussed'
        ELSE 
            'Less Discussed'
    END AS DiscussionLevel
FROM 
    TopPosts tp
LEFT JOIN 
    VoteSummary ts ON tp.PostId = ts.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;