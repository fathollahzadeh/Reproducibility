WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostEngagement AS (
    SELECT 
        p.Id,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(p.Score) OVER() AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id
    ORDER BY 
        TotalScore DESC
    LIMIT 5
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosedReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    COALESCE(e.CommentCount, 0) AS Comments,
    COALESCE(e.VoteCount, 0) AS Votes,
    e.UpVotes,
    e.DownVotes,
    ph.ClosedReasons,
    au.DisplayName AS ActiveUserName,
    au.QuestionCount,
    au.TotalScore
FROM 
    RankedPosts p
LEFT JOIN 
    PostEngagement e ON p.Id = e.Id
LEFT JOIN 
    CloseReasons ph ON p.Id = ph.PostId
LEFT JOIN 
    MostActiveUsers au ON p.OwnerUserId = au.UserId
WHERE 
    p.UserPostRank <= 2 
ORDER BY 
    p.CreationDate DESC;