WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        COUNT(DISTINCT a.Id) AS TotalAcceptedAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.AcceptedAnswerId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(uvs.UpVotes, 0) AS UpVotes,
    COALESCE(uvs.DownVotes, 0) AS DownVotes,
    COALESCE(uvs.TotalPosts, 0) AS TotalPosts,
    COALESCE(uvs.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(uvs.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(pha.TotalAcceptedAnswers, 0) AS TotalAcceptedAnswers,
    phd.Comment AS LastActionComment,
    phd.CreationDate AS LastActionDate
FROM 
    Users u
LEFT JOIN 
    UserVoteStats uvs ON u.Id = uvs.UserId
LEFT JOIN 
    AcceptedAnswers pha ON u.Id = pha.PostId
LEFT JOIN 
    PostHistoryDetails phd ON u.Id = phd.UserId AND phd.rn = 1
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)  
    AND EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id AND p.ViewCount > 100
    )
ORDER BY 
    u.Reputation DESC
LIMIT 50;