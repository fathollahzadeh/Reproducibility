WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 
                (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.AcceptedAnswerId AND v.VoteTypeId = 2)
            ELSE 0
        END AS AcceptedAnswerVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) / NULLIF(COUNT(DISTINCT b.Id), 0) AS AverageBadgeClass,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopBadgedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AverageBadgeClass,
        LastBadgeDate,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        PostCount > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        rp.AcceptedAnswerVotes,
        CASE 
            WHEN rp.rank = 1 THEN 'Top Post' 
            ELSE 'Others' 
        END AS PostCategory
    FROM 
        RankedPosts rp
    INNER JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rank <= 5
),
FinalResults AS (
    SELECT 
        tbu.DisplayName AS TopUserName,
        tp.Title AS TopPostTitle,
        tp.Score AS PostScore,
        tp.CommentCount,
        tp.VoteCount,
        tbu.PostCount AS UserPostCount,
        tbu.AverageBadgeClass
    FROM 
        TopBadgedUsers tbu
    JOIN 
        TopPosts tp ON tbu.UserId = tp.OwnerUserId
    WHERE 
        tbu.UserRank <= 10
)
SELECT 
    FR.TopUserName,
    FR.TopPostTitle,
    FR.PostScore,
    FR.CommentCount,
    FR.VoteCount,
    FR.UserPostCount,
    FR.AverageBadgeClass,
    CASE 
        WHEN FR.PostScore > 100 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS PostRating,
    CASE 
        WHEN FR.CommentCount > 0 THEN 'Open for Discussion'
        ELSE 'No Comments Yet'
    END AS CommentStatus
FROM 
    FinalResults FR
ORDER BY 
    FR.PostScore DESC, 
    FR.UserPostCount DESC;