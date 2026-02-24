WITH UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE 
                WHEN b.Class = 1 THEN 1 
                ELSE 0 
            END) AS GoldBadges,
        SUM(CASE 
                WHEN b.Class = 2 THEN 1 
                ELSE 0 
            END) AS SilverBadges,
        SUM(CASE 
                WHEN b.Class = 3 THEN 1 
                ELSE 0 
            END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b
        ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CommentCount AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(c.TotalComments, 0) AS TotalComments,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        CASE 
            WHEN u.BadgeCount > 10 THEN 'Expert User'
            WHEN u.BadgeCount BETWEEN 5 AND 10 THEN 'Intermediate User'
            ELSE 'Beginner User'
        END AS UserType,
        p.PostRank
    FROM 
        PostsDetails p
    JOIN 
        UserWithBadges u ON p.OwnerUserId = u.UserId
    LEFT JOIN 
        VoteSummary v ON p.PostId = v.PostId
    LEFT JOIN 
        CommentCount c ON p.PostId = c.PostId
)
SELECT 
    *
FROM 
    FinalResults
WHERE 
    (UserType = 'Expert User' OR (PostRank <= 5 AND UserType = 'Intermediate User'))
    AND (ViewCount > 100 OR (BadgeCount IS NOT NULL AND BadgeCount > 0))
ORDER BY 
    CreationDate DESC, 
    Score DESC;