WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
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
        AnswerCount, 
        QuestionCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS RankReputation,
        RANK() OVER (ORDER BY UpVotes DESC) AS RankUpVotes
    FROM 
        UserStats
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.AnswerCount,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN rp.LastEditDate IS NOT NULL THEN 'Edited' 
        ELSE 'Not Edited' 
    END AS EditStatus,
    COALESCE(rp.OwnerUserId, -1) AS OwnerUserId,
    CASE 
        WHEN tu.RankReputation = 1 THEN 'Top Reputation'
        WHEN tu.RankUpVotes = 1 THEN 'Most Upvotes'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers tu
JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerUserId
ORDER BY 
    tu.Reputation DESC, rp.CreationDate DESC
LIMIT 50;