
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(u.LastAccessDate) AS LastAccess
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        ua.UserId, 
        ua.DisplayName, 
        ua.PostsCreated, 
        ua.UpVotes, 
        ua.DownVotes,
        DENSE_RANK() OVER (ORDER BY ua.PostsCreated DESC, ua.UpVotes - ua.DownVotes DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    t.DisplayName AS TopUser, 
    t.PostsCreated, 
    t.UpVotes, 
    t.DownVotes
FROM 
    RankedPosts rp
JOIN 
    TopUsers t ON rp.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL AND ParentId = rp.PostId LIMIT 1)
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Rank, t.UserRank;
