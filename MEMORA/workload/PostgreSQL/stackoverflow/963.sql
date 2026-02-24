WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 999 THEN 'Intermediary'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM 
        Users u
),
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.ReputationLevel,
        pvd.UpVotes,
        pvd.DownVotes,
        (pvd.UpVotes - pvd.DownVotes) AS VoteNet,
        CASE 
            WHEN ur.ReputationLevel = 'Expert' THEN 'Top Author'
            ELSE NULL 
        END AS AuthorStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostVoteDetails pvd ON rp.PostId = pvd.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.Score,
    fs.ViewCount,
    fs.ReputationLevel,
    fs.UpVotes,
    fs.DownVotes,
    fs.VoteNet,
    fs.AuthorStatus
FROM 
    FinalStats fs
WHERE 
    fs.VoteNet > 0
ORDER BY 
    fs.Score DESC
LIMIT 10
OFFSET 0;