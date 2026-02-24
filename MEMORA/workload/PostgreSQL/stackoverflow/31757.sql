
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
UserReputationRank AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(ph.cumulativeComments, 0) AS TotalComments,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    u.DisplayName,
    u.Reputation,
    ur.ReputationRank  -- Changed from u.DensityRank to ur.ReputationRank
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            PostId, 
            COUNT(*) AS cumulativeComments
        FROM 
            Comments
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary vs ON p.Id = vs.PostId
JOIN 
    UserReputationRank ur ON u.Id = ur.UserId  -- Join to get ReputationRank
WHERE 
    EXISTS (
        SELECT 1
        FROM RecursivePostHistory rph
        WHERE rph.PostId = p.Id
        AND rph.PostHistoryTypeId = 11  
    )
AND 
    u.Reputation > 1000  -- Changed to a direct condition instead of a subquery
ORDER BY 
    p.ViewCount DESC,
    UpVotes DESC
LIMIT 50;
