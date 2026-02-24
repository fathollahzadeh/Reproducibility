WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.ViewCount > 100
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 500
),

PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),

EnhancedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        pu.UserId,
        pu.DisplayName AS OwnerDisplayName,
        pv.UpVotes,
        pv.DownVotes,
        pu.Reputation AS OwnerReputation,
        pu.UserRank
    FROM RankedPosts rp
    LEFT JOIN Posts p ON rp.PostId = p.Id
    LEFT JOIN TopUsers pu ON p.OwnerUserId = pu.UserId
    LEFT JOIN PostVotes pv ON p.Id = pv.PostId
    WHERE rp.Rank <= 5
)

SELECT 
    ep.Title,
    ep.CreationDate,
    ep.ViewCount,
    ep.Score,
    COALESCE(ep.UpVotes, 0) AS UpVotes,
    COALESCE(ep.DownVotes, 0) AS DownVotes,
    ep.OwnerDisplayName,
    CASE 
        WHEN ep.OwnerReputation IS NULL THEN 'Unknown'
        WHEN ep.OwnerReputation >= 1000 THEN 'Elite'
        ELSE 'Newbie'
    END AS ReputationCategory
FROM EnhancedPosts ep
WHERE ep.OwnerDisplayName IS NOT NULL
ORDER BY ep.Score DESC, ep.CreationDate DESC;

