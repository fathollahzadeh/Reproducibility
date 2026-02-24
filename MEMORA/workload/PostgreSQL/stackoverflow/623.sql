WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(case when v.VoteTypeId = 2 then 1 else 0 end), 0) AS UpVotesCount,
        COALESCE(SUM(case when v.VoteTypeId = 3 then 1 else 0 end), 0) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.ViewCount, p.AcceptedAnswerId
), 
ReputationRanked AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounties,
        UpVotesCount,
        DownVotesCount,
        RANK() OVER (ORDER BY Reputation DESC) as ReputationRank
    FROM 
        UserReputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    rr.Reputation,
    rr.ReputationRank,
    (CASE 
        WHEN ps.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted' 
     END) AS AcceptanceStatus,
    (CASE 
        WHEN rr.TotalBounties > 0 THEN 'Has Bounties'
        ELSE 'No Bounties' 
     END) AS BountyStatus
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    ReputationRanked rr ON u.Id = rr.UserId
WHERE 
    ps.ViewCount > 100
ORDER BY 
    rr.Reputation DESC, ps.ViewCount DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
