
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
FeaturedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        MAX(p.CreationDate) AS LastActivity,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body
),
TopFeaturedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CommentCount,
        UniqueVoterCount,
        LastActivity,
        RANK() OVER (ORDER BY UniqueVoterCount DESC, LastActivity DESC) AS PopularityRank
    FROM 
        FeaturedPosts
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.BadgeCount,
    tu.UpVotes,
    tu.DownVotes,
    tfp.Title,
    tfp.CommentCount,
    tfp.UniqueVoterCount,
    tfp.LastActivity
FROM 
    TopUsers tu
JOIN 
    TopFeaturedPosts tfp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tfp.PostId LIMIT 1)
WHERE 
    tu.ReputationRank <= 10  
ORDER BY 
    tu.Reputation DESC, 
    tfp.UniqueVoterCount DESC;
