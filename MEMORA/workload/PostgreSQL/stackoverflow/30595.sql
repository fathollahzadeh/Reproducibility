WITH RecursiveTagCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.Id, t.TagName
), 

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
), 

PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.Id = p.AcceptedAnswerId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, a.AcceptedAnswerId, p.OwnerUserId
), 

TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        COUNT(ps.PostId) AS PostsMade,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        RANK() OVER (ORDER BY COUNT(ps.PostId) DESC) AS UserRank
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostSummary ps ON ps.OwnerUserId = ur.UserId
    GROUP BY 
        ur.UserId, ur.Reputation
)

SELECT 
    tt.TagName,
    tt.PostCount,
    u.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.PostsMade,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    RecursiveTagCount tt
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%<', tt.TagName, '>%')
JOIN
    PostSummary ps ON ps.PostId = p.Id
JOIN
    TopUsers tu ON tu.UserId = p.OwnerUserId
JOIN 
    Users u ON u.Id = tu.UserId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tt.PostCount DESC, tu.Reputation DESC;
