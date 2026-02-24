WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
), MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS PostCount,
        SUM(UpVoteCount) AS TotalUpVotes,
        SUM(DownVoteCount) AS TotalDownVotes
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    mu.PostCount,
    mu.TotalUpVotes,
    mu.TotalDownVotes
FROM 
    Users u
JOIN 
    MostActiveUsers mu ON u.Id = mu.OwnerUserId
ORDER BY 
    mu.TotalUpVotes DESC, mu.TotalDownVotes ASC;
