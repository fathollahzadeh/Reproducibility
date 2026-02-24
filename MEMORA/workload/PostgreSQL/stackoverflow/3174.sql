
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 5
),
PostVoteDetails AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FinalPostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        COALESCE(pvd.UpVotes, 0) AS UpVotes,
        COALESCE(pvd.DownVotes, 0) AS DownVotes,
        tp.CommentCount,
        (COALESCE(pvd.UpVotes, 0) - COALESCE(pvd.DownVotes, 0)) AS NetVotes,
        CASE 
            WHEN tp.Score > 10 THEN 'High Score'
            WHEN tp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteDetails pvd ON tp.PostId = pvd.PostId
)
SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.Score,
    fps.UpVotes,
    fps.DownVotes,
    fps.CommentCount,
    fps.NetVotes,
    fps.ScoreCategory
FROM 
    FinalPostStats fps
WHERE 
    fps.CommentCount > 0
ORDER BY 
    fps.NetVotes DESC, fps.Score DESC;
