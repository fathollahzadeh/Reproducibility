WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
VoteCounts AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        COALESCE(vc.UpVotes, 0) AS UpVotes,
        COALESCE(vc.DownVotes, 0) AS DownVotes,
        rp.ViewCount,
        rp.AnswerCount,
        rp.RankScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        VoteCounts vc ON rp.PostId = vc.PostId
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    fp.Title,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.Score IS NOT NULL THEN 'Scored'
        ELSE 'Unscored'
    END AS ScoringStatus,
    CONCAT('https://stackoverflow.com/questions/', fp.PostId) AS PostLink
FROM 
    FilteredPosts fp
WHERE 
    fp.ViewCount > 1000
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 10;