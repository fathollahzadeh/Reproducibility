
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ScoreRank,
    ru.UserId,
    ru.Reputation,
    ru.ReputationRank,
    COALESCE(pvs.UpVotesCount, 0) AS UpVotes,
    COALESCE(pvs.DownVotesCount, 0) AS DownVotes,
    CASE 
        WHEN rp.CommentCount IS NULL THEN 'No Comments'
        ELSE CONCAT(rp.CommentCount, ' Comments')
    END AS CommentInformation
FROM 
    RankedPosts rp
JOIN 
    UserReputation ru ON ru.UserId = rp.PostId
LEFT JOIN 
    PostVoteSummary pvs ON pvs.PostId = rp.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, ru.ReputationRank
LIMIT 25;
