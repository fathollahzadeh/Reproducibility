WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
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
BestPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        ue.UpVotes,
        ue.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        UserEngagement ue ON rp.PostId = ue.UserId
    WHERE 
        rp.ScoreRank <= 5
)
SELECT 
    bp.Title,
    bp.Score,
    bp.ViewCount,
    bp.CommentCount,
    bp.UpVotes,
    bp.DownVotes,
    CASE 
        WHEN bp.Score IS NULL THEN 'No Score Available' 
        ELSE 'Score Present' 
    END AS ScoreStatus
FROM 
    BestPosts bp
ORDER BY 
    bp.Score DESC NULLS LAST;