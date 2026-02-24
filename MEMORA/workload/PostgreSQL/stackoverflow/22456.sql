
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
HighScorePosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5
), 
PostCommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
), 
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
), 
JoinedPostStats AS (
    SELECT 
        hsp.PostId,
        hsp.Title,
        hsp.CreationDate,
        hsp.Score,
        hsp.ViewCount,
        hsp.OwnerDisplayName,
        COALESCE(pcs.TotalComments, 0) AS TotalComments,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes
    FROM 
        HighScorePosts hsp
    LEFT JOIN 
        PostCommentStats pcs ON hsp.PostId = pcs.PostId
    LEFT JOIN 
        PostVoteStats pvs ON hsp.PostId = pvs.PostId
)
SELECT 
    jps.PostId,
    jps.Title,
    jps.CreationDate,
    jps.Score,
    jps.ViewCount,
    jps.OwnerDisplayName,
    jps.TotalComments,
    jps.UpVotes,
    jps.DownVotes,
    CASE 
        WHEN jps.UpVotes + jps.DownVotes = 0 THEN NULL 
        ELSE ROUND((jps.UpVotes::DECIMAL / (jps.UpVotes + jps.DownVotes)) * 100, 2) 
    END AS VotePercentage,
    CASE 
        WHEN jps.Score >= 100 THEN 'Hot'
        WHEN jps.Score BETWEEN 50 AND 99 THEN 'Trending'
        ELSE 'Needs Attention'
    END AS PostHeatLevel
FROM 
    JoinedPostStats jps
WHERE 
    jps.TotalComments > 0
ORDER BY 
    jps.Score DESC, jps.ViewCount DESC;
