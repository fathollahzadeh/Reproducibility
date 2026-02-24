
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(bs.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges bs ON u.Id = bs.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalBadges
    FROM 
        PostStatistics ps
    INNER JOIN 
        UserReputation ur ON ps.OwnerUserId = ur.UserId
    WHERE 
        ps.UserPostRank <= 5
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.DisplayName,
    pd.Reputation,
    pd.TotalBadges,
    'Score: ' || (pd.UpVotes - pd.DownVotes) AS PostScore
FROM 
    PostDetails pd
ORDER BY 
    pd.CommentCount DESC, (pd.UpVotes - pd.DownVotes) DESC
LIMIT 10;
