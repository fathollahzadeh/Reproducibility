
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) FILTER (WHERE c.Score > 0) AS PositiveCommentCount,
        COUNT(c.Id) FILTER (WHERE c.Score < 0) AS NegativeCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

RecentVoteCounts AS (
    SELECT 
        Vote.PostId,
        COUNT(*) FILTER (WHERE vt.Name = 'UpMod') AS UpVoteCount,
        COUNT(*) FILTER (WHERE vt.Name = 'DownMod') AS DownVoteCount
    FROM 
        Votes Vote
    JOIN 
        VoteTypes vt ON Vote.VoteTypeId = vt.Id
    WHERE 
        Vote.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        Vote.PostId
),

FinalPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerUserId,
        rp.PostRank,
        COALESCE(rvc.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(rvc.DownVoteCount, 0) AS DownVoteCount,
        rp.PositiveCommentCount,
        rp.NegativeCommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVoteCounts rvc ON rp.PostId = rvc.PostId
    WHERE 
        (rp.Score > 10 OR rp.PositiveCommentCount > 5)
        AND (rvc.DownVoteCount IS NULL OR rvc.UpVoteCount > rvc.DownVoteCount)
)

SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.Score,
    fps.UpVoteCount,
    fps.DownVoteCount,
    fps.PositiveCommentCount,
    fps.NegativeCommentCount
FROM 
    FinalPostStats fps
JOIN 
    Users u ON fps.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id 
WHERE 
    fps.PostRank <= 3 
    AND (b.Class IN (1, 2) OR b.Id IS NULL)  
ORDER BY 
    fps.Score DESC, fps.CreationDate DESC;
