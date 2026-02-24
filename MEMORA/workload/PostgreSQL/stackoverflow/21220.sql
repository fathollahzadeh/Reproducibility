
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
), 
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
), 
TopUsers AS (
    SELECT 
        UserId,
        ROW_NUMBER() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS BountyRank
    FROM 
        Votes v 
    WHERE 
        v.VoteTypeId IN (8, 9)  
    GROUP BY 
        UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    u.CreationDate,
    us.VoteCount,
    us.UpVotes,
    us.DownVotes,
    cp.CommentCount,
    t.UserId AS TopBountyUserId,
    t.BountyRank
FROM 
    Users u
JOIN 
    UserVoteSummary us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    us.QuestionCount > 10 AND 
    (us.UpVotes > us.DownVotes OR us.VoteCount IS NULL)
ORDER BY 
    u.Reputation DESC, us.VoteCount DESC;
