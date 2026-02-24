
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(p.Id) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM 
        Users u
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ur.Reputation,
        ur.ReputationLevel,
        pvc.UpVotes,
        pvc.DownVotes,
        rp.TotalPosts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    WHERE 
        rp.rn = 1 
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ReputationLevel,
    COALESCE(pd.UpVotes, 0) AS UpVotes,
    COALESCE(pd.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN pd.TotalPosts = 0 THEN 'No posts'
        WHEN pd.TotalPosts > 1 THEN 'Multiple posts'
        ELSE 'Single post'
    END AS PostsClassification,
    CONCAT(pd.Title, ' - ', pd.ReputationLevel) AS TitleWithReputation
FROM 
    PostDetails pd
WHERE 
    pd.Reputation IS NOT NULL
ORDER BY 
    pd.CreationDate DESC;
