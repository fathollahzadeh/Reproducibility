
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        OwnerUserId AS UserId,
        MAX(CreationDate) AS LastPostDate
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
HighScoringPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 10
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalTagWikis,
    u.TotalScore,
    ra.LastPostDate,
    hsp.Title AS HighScoringPostTitle,
    hsp.Score AS HighScoringPostScore,
    pvs.UpVotes,
    pvs.DownVotes
FROM 
    UserPostStats u
LEFT JOIN 
    RecentActivity ra ON u.UserId = ra.UserId
LEFT JOIN 
    HighScoringPosts hsp ON u.UserId = hsp.OwnerUserId AND hsp.Rank = 1
LEFT JOIN 
    PostVoteStats pvs ON hsp.PostId = pvs.PostId
WHERE 
    u.TotalPosts > 5
ORDER BY 
    u.TotalScore DESC, ra.LastPostDate DESC;
