
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownvoteCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.PostTypeId, p.AcceptedAnswerId
),
TopPosters AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpvoteCount) AS TotalUpvotes,
        SUM(ps.DownvoteCount) AS TotalDownvotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
RecentQuestions AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    WHERE 
        p.PostTypeId = 1 
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.CommentCount,
    tq.UpvoteCount,
    tq.DownvoteCount,
    CONCAT(u.DisplayName, ' (', p.OwnerUserId, ')') AS OwnerDisplayName,
    COALESCE(bt.Name, 'No Badge') AS Badge,
    CASE 
        WHEN ps.AcceptedAnswer = -1 THEN 'No Accepted Answer' 
        ELSE 'Accepted Answer Exists' 
    END AS AnswerStatus
FROM 
    RecentQuestions tq
JOIN 
    Posts p ON tq.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges bt ON u.Id = bt.UserId AND bt.Class = 1 
JOIN 
    PostStats ps ON p.Id = ps.PostId
WHERE 
    tq.Rank <= 100 
    AND u.Reputation > 1000
ORDER BY 
    tq.CreationDate DESC;
