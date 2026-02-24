
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.Body, 'No content') AS PostBody,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.AcceptedAnswerId
), FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Pending'
        END AS AnswerStatus,
        (UpVoteCount - DownVoteCount) AS NetVote,
        CASE 
            WHEN rp.UserPostRank <= 5 THEN 'Top Posts'
            ELSE 'Other Posts'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostBody IS NOT NULL AND rp.PostBody <> 'No content'
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 0
), FinalReport AS (
    SELECT 
        f.PostId,
        f.Title,
        f.PostBody,
        f.CreationDate,
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalPosts,
        f.AnswerStatus,
        f.NetVote,
        DENSE_RANK() OVER (ORDER BY ua.Reputation DESC) AS UserRank,
        f.PostCategory
    FROM 
        FilteredPosts f
    JOIN 
        UserActivity ua ON f.OwnerUserId = ua.UserId
    WHERE 
        f.NetVote > 0
        AND f.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT 
    PostId,
    Title,
    PostBody,
    CreationDate,
    DisplayName,
    Reputation,
    TotalPosts,
    AnswerStatus,
    NetVote,
    UserRank,
    PostCategory
FROM 
    FinalReport
ORDER BY 
    UserRank, CreationDate DESC;
