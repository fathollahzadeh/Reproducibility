WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.OwnerDisplayName,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Views,
    us.PostCount,
    us.AnswerCount,
    us.QuestionCount,
    us.AcceptedQuestions,
    tt.TagName,
    COALESCE(rph.Title, 'No recent edits') AS RecentPostTitle,
    COALESCE(rph.OwnerDisplayName, 'N/A') AS PostOwner,
    rph.CreationDate AS RecentEditDate,
    CASE 
        WHEN rph.PostTypeId IS NULL THEN 'N/A'
        ELSE CASE 
            WHEN rph.PostTypeId = 1 THEN 'Question'
            WHEN rph.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END
    END AS PostType
FROM 
    UserStats us
LEFT JOIN 
    TopTags tt ON us.PostCount > 0
LEFT JOIN 
    RecentPostHistory rph ON us.UserId = rph.UserId AND rph.rn = 1
ORDER BY 
    us.Reputation DESC, us.Views DESC
LIMIT 100;