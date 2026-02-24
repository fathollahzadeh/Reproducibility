
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId, 
        ps.VoteCount, 
        ps.UpVotes, 
        ps.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY ps.PostId ORDER BY ps.VoteCount DESC) AS rn
    FROM 
        PostVoteStats ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.LastPostDate,
    COALESCE(rp.PostId, -1) AS TopVotedPostId,
    COALESCE(rp.VoteCount, 0) AS TopVotedPostVoteCount,
    COALESCE(rp.UpVotes, 0) AS TopVotedPostUpVotes,
    COALESCE(rp.DownVotes, 0) AS TopVotedPostDownVotes
FROM 
    UserPostStats ups
LEFT JOIN 
    RankedPosts rp ON ups.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId AND rp.rn = 1)
WHERE 
    ups.Reputation > 100
ORDER BY 
    ups.Reputation DESC, 
    ups.TotalPosts DESC;
