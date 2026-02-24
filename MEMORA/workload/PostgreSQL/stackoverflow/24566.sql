
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RN <= 5
),
CommentsCount AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        COALESCE(cc.CommentCount, 0) AS CommentCount,
        COALESCE(vc.UpVotes, 0) AS UpVotes,
        COALESCE(vc.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN vc.TotalVotes IS NULL OR vc.TotalVotes = 0 THEN 'No Votes Yet'
            ELSE 'Has Votes'
        END AS VoteStatus
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsCount cc ON tp.PostId = cc.PostId
    LEFT JOIN 
        VoteCounts vc ON tp.PostId = vc.PostId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.VoteStatus,
    ROUND(CAST(pd.Score AS numeric) / NULLIF(pd.ViewCount, 0) + 1, 2) AS ScorePerView,
    CASE 
        WHEN pd.CommentCount > 10 THEN 'Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    PostDetails pd
WHERE 
    pd.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;
