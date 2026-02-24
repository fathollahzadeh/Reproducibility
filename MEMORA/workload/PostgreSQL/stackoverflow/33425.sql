
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        CAST(p.Title AS VARCHAR(300)) AS FullTitle,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        CONCAT(ph.FullTitle, ' -> ', a.Title) AS FullTitle,
        ph.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON ph.Id = a.ParentId
    WHERE 
        a.PostTypeId = 2  
),
VoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        ph.FullTitle,
        ph.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(vc.UpVotes, 0) AS UpVotes,
        COALESCE(vc.DownVotes, 0) AS DownVotes,
        COALESCE(ur.Reputation, 0) AS UserReputation,
        ur.BadgeCount
    FROM 
        PostHierarchy ph
    JOIN 
        Posts p ON p.Id = ph.Id
    LEFT JOIN 
        VoteCounts vc ON p.Id = vc.PostId
    LEFT JOIN 
        Users u ON u.Id = ph.OwnerUserId
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
),
FinalStats AS (
    SELECT 
        PostId,
        FullTitle,
        CreationDate,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        UserReputation,
        BadgeCount,
        CASE 
            WHEN UpVotes > DownVotes THEN 'Positive' 
            ELSE 'Negative' 
        END AS VoteSentiment,
        ROW_NUMBER() OVER (PARTITION BY UserReputation ORDER BY UpVotes DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    FullTitle,
    CreationDate,
    OwnerDisplayName,
    UpVotes,
    DownVotes,
    UserReputation,
    BadgeCount,
    VoteSentiment
FROM 
    FinalStats
WHERE 
    Rank <= 10
ORDER BY 
    UserReputation DESC, UpVotes DESC;
